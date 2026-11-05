package com.cstore.app.controller;

import static com.cstore.app.service.CommerceSupport.bad;
import static com.cstore.app.service.CommerceSupport.distance;
import static com.cstore.app.service.CommerceSupport.validCoordinates;

import com.cstore.app.dto.DeliveryDtos.DeliveryLocation;
import com.cstore.app.dto.DeliveryDtos.DeliveryQuote;
import com.cstore.app.dto.DeliveryDtos.NearbyBranch;
import com.cstore.app.dto.DeliveryDtos.QuoteInput;
import com.cstore.app.repository.Stores;
import com.cstore.app.service.CommerceSupport;
import com.cstore.app.service.DeliveryService;
import jakarta.validation.Valid;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;
import org.springframework.security.core.Authentication;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.server.ResponseStatusException;

/** Vị trí giao hàng, cửa hàng gần khách và báo phí trước khi đặt hàng. */
@RestController
@RequestMapping("/api")
@Transactional(readOnly = true)
public class CustomerController {
  private final CommerceSupport support;
  private final Stores stores;
  private final DeliveryService delivery;

  public CustomerController(CommerceSupport support, Stores stores, DeliveryService delivery) {
    this.support = support;
    this.stores = stores;
    this.delivery = delivery;
  }

  @GetMapping("/customer/location")
  public DeliveryLocation deliveryLocation(Authentication authentication) {
    var user = support.current(authentication);
    return user.deliveryLatitude == null
            || user.deliveryLongitude == null
            || user.deliveryAddress == null
        ? null
        : new DeliveryLocation(
            user.deliveryAddress, user.deliveryLatitude, user.deliveryLongitude, true);
  }

  @PutMapping("/customer/location")
  @Transactional
  public DeliveryLocation deliveryLocation(
      Authentication authentication, @Valid @RequestBody DeliveryLocation input) {
    var user = support.current(authentication);
    user.deliveryAddress = input.address().trim();
    user.deliveryLatitude = input.latitude();
    user.deliveryLongitude = input.longitude();
    return new DeliveryLocation(
        user.deliveryAddress, user.deliveryLatitude, user.deliveryLongitude, true);
  }

  @PostMapping("/customer/delivery-quote")
  public DeliveryQuote deliveryQuote(@Valid @RequestBody QuoteInput input) {
    return delivery.quote(
        stores.findById(input.storeId()).orElseThrow(() -> bad("Chi nhánh không tồn tại")),
        input.latitude(),
        input.longitude());
  }

  @GetMapping("/customer/nearby")
  public List<NearbyBranch> nearby(@RequestParam double latitude, @RequestParam double longitude) {
    validCoordinates(latitude, longitude);
    var result = new ArrayList<NearbyBranch>();
    for (var store : stores.findAll()) {
      if (store.isActive()
          && store.latitude != null
          && store.longitude != null
          && distance(store.latitude, store.longitude, latitude, longitude) <= 10) {
        try {
          var quote = delivery.quote(store, latitude, longitude);
          result.add(
              new NearbyBranch(store.id, quote.distanceKm(), quote.durationSeconds(), quote.fee()));
        } catch (ResponseStatusException e) {
          if (e.getStatusCode().value() != 400) {
            throw e;
          }
        }
      }
    }
    result.sort(Comparator.comparingDouble(NearbyBranch::distanceKm));
    return result;
  }
}
